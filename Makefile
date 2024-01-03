MODELS := cablebox

OPENSCAD := openscad
OPENSCAD_FLAGS := \
	-q \
	--hardwarnings \
	--check-parameters=true \
	--check-parameter-ranges=true

SRC_DIR := src
DIST_DIR := dist
DEPENDS_DIR := .depends

include $(wildcard $(DEPENDS_DIR)/*.mk)

.PHONY: all
all: build

.DEFAULT_GOAL:=build
.PHONY: build

define build_model =
ifeq ("$(wildcard $(SRC_DIR)/$(1).json)","")
$$(eval $$(call build_plain_model,$(1)))
else
$$(eval $$(call build_parametric_model,$(1)))
endif
endef

define build_plain_model
$$(DIST_DIR)/$(1).3mf: $$(SRC_DIR)/$(1).scad | $$(DIST_DIR) $$(DEPENDS_DIR)
	$$(OPENSCAD) $$(OPENSCAD_FLAGS) -o $$@ -d $$(DEPENDS_DIR)/$(1).mk $$<

build: $(DIST_DIR)/$(1).3mf
endef

define build_parametric_model
$(foreach param_set,$(shell jq -r '.parameterSets | keys[]' $(SRC_DIR)/$(1).json),
	$(eval $(call build_model_with_params,$(1),$(param_set))))
endef

define build_model_with_params
$$(DIST_DIR)/$(1)@$(2).3mf: $$(SRC_DIR)/$(1).scad $$(SRC_DIR)/$(1).json | $$(DIST_DIR) $$(DEPENDS_DIR)
	$$(OPENSCAD) $$(OPENSCAD_FLAGS) -o $$@ -d $$(DEPENDS_DIR)/$(1)@$(2).mk -p $$(SRC_DIR)/$(1).json -P $(2) $$<

build: $(DIST_DIR)/$(1)@$(2).3mf
endef

$(foreach model,$(MODELS),$(eval $(call build_model,$(model))))

$(DIST_DIR) $(DEPENDS_DIR):
	mkdir $@

.PHONY: clean
clean:
	rm -fr $(DIST_DIR) $(DEPENDS_DIR)
