SRC_DIR := src
DIST_DIR := dist
DEPENDS_DIR := .depends
MODEL := cablebox

SRC_FILE := $(patsubst %,$(SRC_DIR)/%.scad,$(MODEL))
PARAM_FILE := $(patsubst %,$(SRC_DIR)/%.json,$(MODEL))
PARAM_SETS := $(shell jq -r '.parameterSets | keys[]' $(PARAM_FILE))
DIST_FILES := $(patsubst %,$(DIST_DIR)/$(MODEL)@%.3mf,$(PARAM_SETS))
DEPENDS_FILES := $(patsubst %,$(DEPENDS_DIR)/$(MODEL)@%.mk,$(PARAM_SETS))

.PHONY: build
build: $(DIST_FILES)

-include $(DEPENDS_FILES)

$(DIST_DIR) $(DEPENDS_DIR):
	mkdir -p $@

$(DIST_FILES): $(DIST_DIR)/$(MODEL)@%.3mf: $(SRC_DIR)/$(MODEL).scad $(DIST_DIR) $(DEPENDS_DIR)
	openscad -o $@ -d $(DEPENDS_DIR)/$*.mk -m make -p $(PARAM_FILE) -P $* -q --hardwarnings $<

.PHONY: clean
clean:
	rm -rf $(DIST_DIR) $(DEPENDS_DIR)
