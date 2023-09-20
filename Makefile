NAME := cablebox

SCAD_FILE := src/$(NAME).scad
PARAM_FILE := src/$(NAME).json
PARAM_SETS := $(shell jq -r '.parameterSets | keys[]' $(PARAM_FILE))

OUTPUT_DIR := output
OUTPUT_FILES := $(patsubst %,$(OUTPUT_DIR)/$(NAME)_%.3mf,$(PARAM_SETS))

DEPENDS_DIR := .depends
DEPENDS_FILES := $(patsubst %,$(DEPENDS_DIR)/$(NAME)_%.mk,$(PARAM_SETS))

BUILD_DIRS := $(OUTPUT_DIR) $(DEPENDS_DIR)

.PHONY: build
build: $(OUTPUT_FILES)

-include $(DEPENDS_FILES)

$(BUILD_DIRS):
	mkdir -p $@

$(OUTPUT_FILES): $(OUTPUT_DIR)/$(NAME)_%.3mf: $(SCAD_FILE) $(PARAM_FILE) $(BUILD_DIRS)
	openscad \
		-o $(OUTPUT_DIR)/$(NAME)_$*.3mf \
		-d $(DEPENDS_DIR)/$(NAME)_$*.mk \
		-m make \
		-p $(PARAM_FILE) \
		-P $* \
		--hardwarnings \
		$<

.PHONY: assets
assets: assets/cablebox_exploded.png

assets/cablebox_exploded.png: $(SCAD_FILE)
	openscad \
		-o $@ \
		-d $(DEPENDS_DIR)/cablebox_exploded.mk \
		-m make \
		-D model='"exploded"' \
		--render \
		--imgsize 1600,1200 \
		--hardwarnings \
		$<

.PHONY: clean
clean:
	rm -rf $(BUILD_DIRS)
