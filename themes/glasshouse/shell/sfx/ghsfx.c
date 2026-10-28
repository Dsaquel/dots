#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdatomic.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>
#include <signal.h>
#include <spa/param/audio/format-utils.h>
#include <pipewire/pipewire.h>

#define RATE 48000
#define VOICES 96
#define QUEUE 128
#define CUES 512

struct cue {
	char key[512];
	float *pcm;
	uint32_t len;
};

struct voice {
	const float *pcm;
	uint32_t len;
	uint32_t pos;
	uint32_t wait;
	unsigned epoch;
	float gain;
};

struct app {
	struct pw_main_loop *loop;
	struct pw_stream *stream;
	struct spa_source *timer;
	struct cue cues[CUES];
	int ncues;
	struct voice voices[VOICES];
	struct voice queue[QUEUE];
	atomic_uint head;
	atomic_uint tail;
	atomic_uint hushed;
	int keep;
	uint64_t linger;
	int active;
	uint64_t until;
	char line[2048];
	size_t fill;
};

static uint64_t now_ns(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (uint64_t)ts.tv_sec * 1000000000ull + ts.tv_nsec;
}

static uint32_t le32(const uint8_t *p) {
	return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24;
}

static uint16_t le16(const uint8_t *p) {
	return p[0] | p[1] << 8;
}

static int load(struct app *a, const char *key, const char *path) {
	if (a->ncues >= CUES)
		return -1;
	FILE *f = fopen(path, "rb");
	if (!f)
		return -1;
	long size = fseek(f, 0, SEEK_END) ? -1 : ftell(f);
	uint8_t *raw = size >= 12 && !fseek(f, 0, SEEK_SET) ? malloc(size) : NULL;
	size_t got = raw ? fread(raw, 1, size, f) : 0;
	fclose(f);
	if (!raw || got != (size_t)size || memcmp(raw, "RIFF", 4) || memcmp(raw + 8, "WAVE", 4)) {
		fprintf(stderr, "ghsfx: skip %s (not a readable WAVE file)\n", path);
		free(raw);
		return -1;
	}
	uint16_t format = 0, channels = 0, bits = 0;
	uint32_t rate = 0, bytes = 0;
	const uint8_t *data = NULL;
	long off = 12;
	while (off + 8 <= size) {
		uint32_t len = le32(raw + off + 4);
		if (!memcmp(raw + off, "fmt ", 4) && len >= 16 && off + 24 <= size) {
			format = le16(raw + off + 8);
			channels = le16(raw + off + 10);
			rate = le32(raw + off + 12);
			bits = le16(raw + off + 22);
		} else if (!memcmp(raw + off, "data", 4)) {
			data = raw + off + 8;
			bytes = off + 8 + len > size ? size - off - 8 : len;
			break;
		}
		off += 8 + len + (len & 1);
	}
	if (!data || format != 1 || bits != 16 || rate != RATE || channels == 0) {
		fprintf(stderr, "ghsfx: skip %s (16-bit PCM at 48 kHz only)\n", path);
		free(raw);
		return -1;
	}
	uint32_t frames = bytes / (2 * channels);
	float *pcm = malloc(sizeof(float) * frames);
	if (!pcm) {
		free(raw);
		return -1;
	}
	for (uint32_t i = 0; i < frames; i++) {
		float s = 0;
		for (uint16_t c = 0; c < channels; c++)
			s += (int16_t)le16(data + 2 * (i * channels + c)) / 32768.0f;
		pcm[i] = s / channels;
	}
	free(raw);
	struct cue *q = &a->cues[a->ncues];
	snprintf(q->key, sizeof(q->key), "%s", key);
	q->pcm = pcm;
	q->len = frames;
	return a->ncues++;
}

static void preload(struct app *a, const char *root) {
	DIR *top = opendir(root);
	if (!top)
		return;
	struct dirent *w;
	while ((w = readdir(top))) {
		if (w->d_name[0] == 46)
			continue;
		char sub[1024];
		snprintf(sub, sizeof(sub), "%s/%s", root, w->d_name);
		DIR *dir = opendir(sub);
		if (!dir)
			continue;
		struct dirent *e;
		while ((e = readdir(dir))) {
			size_t n = strlen(e->d_name);
			if (n < 5 || strcmp(e->d_name + n - 4, ".wav"))
				continue;
			char path[2048], key[512];
			snprintf(path, sizeof(path), "%s/%s", sub, e->d_name);
			snprintf(key, sizeof(key), "%s/%.*s", w->d_name, (int)(n - 4), e->d_name);
			load(a, key, path);
		}
		closedir(dir);
	}
	closedir(top);
}

static int find(struct app *a, const char *key) {
	for (int i = 0; i < a->ncues; i++)
		if (!strcmp(a->cues[i].key, key))
			return i;
	return key[0] == 47 ? load(a, key, key) : -1;
}

static void on_process(void *userdata) {
	struct app *a = userdata;
	struct pw_buffer *b = pw_stream_dequeue_buffer(a->stream);
	if (!b)
		return;
	struct spa_buffer *buf = b->buffer;
	float *out = buf->datas[0].data;
	if (!out) {
		pw_stream_queue_buffer(a->stream, b);
		return;
	}
	uint32_t n = buf->datas[0].maxsize / sizeof(float);
	if (b->requested && b->requested < n)
		n = b->requested;
	unsigned t = atomic_load_explicit(&a->tail, memory_order_relaxed);
	unsigned h = atomic_load_explicit(&a->head, memory_order_acquire);
	for (; t != h; t++)
		for (int v = 0; v < VOICES; v++)
			if (!a->voices[v].pcm) {
				a->voices[v] = a->queue[t % QUEUE];
				break;
			}
	atomic_store_explicit(&a->tail, t, memory_order_release);
	unsigned epoch = atomic_load_explicit(&a->hushed, memory_order_acquire);
	memset(out, 0, n * sizeof(float));
	for (int v = 0; v < VOICES; v++) {
		struct voice *x = &a->voices[v];
		if (!x->pcm)
			continue;
		if (x->wait && x->epoch != epoch) {
			x->pcm = NULL;
			continue;
		}
		uint32_t skip = x->wait < n ? x->wait : n;
		x->wait -= skip;
		uint32_t m = x->len - x->pos < n - skip ? x->len - x->pos : n - skip;
		for (uint32_t i = 0; i < m; i++)
			out[skip + i] += x->pcm[x->pos + i] * x->gain;
		x->pos += m;
		if (x->pos >= x->len)
			x->pcm = NULL;
	}
	for (uint32_t i = 0; i < n; i++)
		out[i] = out[i] > 1.0f ? 1.0f : out[i] < -1.0f ? -1.0f : out[i];
	buf->datas[0].chunk->offset = 0;
	buf->datas[0].chunk->stride = sizeof(float);
	buf->datas[0].chunk->size = n * sizeof(float);
	pw_stream_queue_buffer(a->stream, b);
}

static void arm(struct app *a) {
	uint64_t now = now_ns();
	uint64_t left = a->until > now ? a->until - now : 1;
	struct timespec value;
	value.tv_sec = left / 1000000000ull;
	value.tv_nsec = left % 1000000000ull;
	pw_loop_update_timer(pw_main_loop_get_loop(a->loop), a->timer, &value, NULL, false);
}

static void on_timer(void *userdata, uint64_t expirations) {
	struct app *a = userdata;
	if (a->keep || !a->active)
		return;
	if (now_ns() < a->until) {
		arm(a);
		return;
	}
	pw_stream_set_active(a->stream, false);
	a->active = 0;
}

static void play(struct app *a, const char *key, float gain, float delay) {
	int i = find(a, key);
	if (i < 0) {
		fprintf(stderr, "ghsfx: no cue %s\n", key);
		return;
	}
	unsigned h = atomic_load_explicit(&a->head, memory_order_relaxed);
	unsigned t = atomic_load_explicit(&a->tail, memory_order_acquire);
	if (h - t >= QUEUE)
		return;
	struct voice *v = &a->queue[h % QUEUE];
	v->pcm = a->cues[i].pcm;
	v->len = a->cues[i].len;
	v->pos = 0;
	v->wait = delay > 0 ? (uint32_t)((delay < 3600000.0f ? delay : 3600000.0f) * RATE / 1000.0f) : 0;
	v->epoch = atomic_load_explicit(&a->hushed, memory_order_relaxed);
	v->gain = gain;
	atomic_store_explicit(&a->head, h + 1, memory_order_release);
	uint64_t end = now_ns() + ((uint64_t)a->cues[i].len + v->wait) * 1000000000ull / RATE + a->linger;
	if (end > a->until)
		a->until = end;
	if (!a->active) {
		pw_stream_set_active(a->stream, true);
		a->active = 1;
	}
	if (!a->keep)
		arm(a);
}

static void hold(struct app *a, int on) {
	a->keep = on;
	if (on && !a->active) {
		pw_stream_set_active(a->stream, true);
		a->active = 1;
	}
	if (!on && a->active) {
		uint64_t end = now_ns() + a->linger;
		if (end > a->until)
			a->until = end;
		arm(a);
	}
}

static void on_stdin(void *userdata, int fd, uint32_t mask) {
	struct app *a = userdata;
	ssize_t r = read(fd, a->line + a->fill, sizeof(a->line) - 1 - a->fill);
	if (r <= 0) {
		pw_main_loop_quit(a->loop);
		return;
	}
	a->fill += r;
	a->line[a->fill] = 0;
	char *start = a->line, *nl;
	while ((nl = memchr(start, 10, a->line + a->fill - start))) {
		*nl = 0;
		char key[512];
		float gain = 1.0f, delay = 0.0f;
		if (sscanf(start, "%511s %f %f", key, &gain, &delay) >= 1) {
			if (!strcmp(key, "hold"))
				hold(a, gain > 0.5f);
			else if (!strcmp(key, "hush"))
				atomic_fetch_add_explicit(&a->hushed, 1, memory_order_release);
			else
				play(a, key, gain, delay);
		}
		start = nl + 1;
	}
	a->fill = a->line + a->fill - start;
	memmove(a->line, start, a->fill);
	if (a->fill >= sizeof(a->line) - 1)
		a->fill = 0;
}

static void on_state(void *userdata, enum pw_stream_state old, enum pw_stream_state state, const char *error) {
	fprintf(stderr, "ghsfx: %s%s%s\n", pw_stream_state_as_string(state), error ? " " : "", error ? error : "");
	if (state == PW_STREAM_STATE_ERROR || state == PW_STREAM_STATE_UNCONNECTED)
		pw_main_loop_quit(((struct app *)userdata)->loop);
}

static const struct pw_stream_events events = {
	PW_VERSION_STREAM_EVENTS,
	.state_changed = on_state,
	.process = on_process,
};

static void quit(void *userdata, int sig) {
	struct app *a = userdata;
	pw_main_loop_quit(a->loop);
}

int main(int argc, char *argv[]) {
	static struct app a;
	const char *target = NULL, *latency = "256/48000";
	a.linger = 250000000ull;
	int i = 1;
	for (; i < argc && argv[i][0] == 45; i++) {
		if (!strcmp(argv[i], "--target") && i + 1 < argc)
			target = argv[++i];
		else if (!strcmp(argv[i], "--latency") && i + 1 < argc)
			latency = argv[++i];
		else if (!strcmp(argv[i], "--keep"))
			a.keep = 1;
		else if (!strcmp(argv[i], "--linger") && i + 1 < argc)
			a.linger = strtoull(argv[++i], NULL, 10) * 1000000ull;
	}
	for (; i < argc; i++)
		preload(&a, argv[i]);
	pw_init(&argc, &argv);
	a.loop = pw_main_loop_new(NULL);
	struct pw_loop *loop = pw_main_loop_get_loop(a.loop);
	pw_loop_add_signal(loop, SIGINT, quit, &a);
	pw_loop_add_signal(loop, SIGTERM, quit, &a);
	a.timer = pw_loop_add_timer(loop, on_timer, &a);
	pw_loop_add_io(loop, 0, SPA_IO_IN | SPA_IO_HUP | SPA_IO_ERR, false, on_stdin, &a);
	struct pw_properties *props = pw_properties_new(
		PW_KEY_MEDIA_TYPE, "Audio",
		PW_KEY_MEDIA_CATEGORY, "Playback",
		PW_KEY_MEDIA_ROLE, "Music",
		PW_KEY_APP_NAME, "glasshouse",
		PW_KEY_NODE_NAME, "glasshouse-sfx",
		PW_KEY_NODE_LATENCY, latency,
		NULL);
	if (target) {
		pw_properties_set(props, PW_KEY_TARGET_OBJECT, target);
		pw_properties_set(props, "node.dont-fallback", "true");
		pw_properties_set(props, "node.dont-move", "true");
		pw_properties_set(props, PW_KEY_NODE_DONT_RECONNECT, "true");
	}
	a.stream = pw_stream_new_simple(loop, "glasshouse-sfx", props, &events, &a);
	uint8_t buffer[1024];
	struct spa_pod_builder bld = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));
	struct spa_audio_info_raw info;
	memset(&info, 0, sizeof(info));
	info.format = SPA_AUDIO_FORMAT_F32;
	info.channels = 1;
	info.rate = RATE;
	const struct spa_pod *params[1];
	params[0] = spa_format_audio_raw_build(&bld, SPA_PARAM_EnumFormat, &info);
	pw_stream_connect(a.stream, PW_DIRECTION_OUTPUT, PW_ID_ANY,
		PW_STREAM_FLAG_AUTOCONNECT | PW_STREAM_FLAG_MAP_BUFFERS | PW_STREAM_FLAG_RT_PROCESS | (a.keep ? 0 : PW_STREAM_FLAG_INACTIVE),
		params, 1);
	a.active = a.keep;
	fprintf(stderr, "ghsfx: %d cues\n", a.ncues);
	pw_main_loop_run(a.loop);
	pw_stream_destroy(a.stream);
	pw_main_loop_destroy(a.loop);
	pw_deinit();
	return 0;
}
