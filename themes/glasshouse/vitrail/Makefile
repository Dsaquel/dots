CXXFLAGS ?= -O2
CXXFLAGS += -fPIC -std=c++2b -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers
LDFLAGS  += -shared
EXTRA    := $(shell $(CXX) --no-gnu-unique -x c++ -E /dev/null >/dev/null 2>&1 && echo --no-gnu-unique)
LUA      := $(firstword $(foreach p,lua5.5 lua55 lua lua5.4 lua54,$(shell pkg-config --exists $(p) && echo $(p))))
PKGS     = pixman-1 libdrm hyprland libinput libudev wayland-server xkbcommon pangocairo librsvg-2.0 $(LUA)
INCLUDES = $(shell pkg-config --cflags $(PKGS)) -Isrc -Ibuild
OBJ      = $(patsubst src/%.cpp,build/%.o,$(wildcard src/*.cpp src/*/*.cpp))
HEADERS  = $(wildcard src/*/*.hpp)
STAGES   = $(wildcard shaders/*.frag shaders/*.vert)
PARTS    = $(wildcard shaders/*/*.glsl)
EXPANDED = $(patsubst shaders/%,build/glsl/%,$(STAGES))
SHADERS  = $(patsubst shaders/%,build/%.inc,$(STAGES))

all: vitrail.so

build/glsl/%: shaders/% $(PARTS) shaders/include.awk
	@mkdir -p $(@D)
	awk -f shaders/include.awk $< > $@.tmp && mv $@.tmp $@

build/%.inc: build/glsl/%
	{ printf 'R"#('; cat $<; printf ')#"\n'; } > $@.tmp && mv $@.tmp $@

build/%.o: src/%.cpp $(HEADERS) $(SHADERS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(EXTRA) $(INCLUDES) -c $< -o $@

vitrail.so: $(OBJ)
	$(CXX) $(LDFLAGS) $(EXTRA) $^ -o $@ $(shell pkg-config --libs pangocairo librsvg-2.0)

check: $(EXPANDED)
	for f in $^; do glslangValidator $$f || exit 1; done

clean:
	rm -rf build vitrail.so

.SECONDARY: $(EXPANDED)
.PHONY: all check clean
