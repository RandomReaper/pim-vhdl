.DEFAULT_GOAL := all

.PHONY: clean
clean:
	rm -rf tmp

SOURCEDIR = .
BUILDDIR = tmp
XISE := $(shell find $(SOURCEDIR) -name '*.xise')
DEPS := $(addprefix $(BUILDDIR)/,$(XISE:%.xise=%.deps))
TODO := $(addprefix $(BUILDDIR)/,$(XISE:%.xise=%.result))

ifeq (,$(findstring clean,$(MAKECMDGOALS)))
	-include $(DEPS)
endif

.PHONY: all
all: tmp  $(DEPS) $(TODO)

$(TODO): $(DEPS)

tmp:
	@mkdir -p tmp

$(BUILDDIR)/%.deps:%.xise
	@echo Computing dependencies for $<
	@mkdir -p $(dir $@)
	@echo -n $<: > $@
	@echo $(shell xise-list-vhdl.sh $(dir $<)) >> $@

$(BUILDDIR)/%.result:%.xise
	@echo Simulating $<
	@mkdir -p $(dir $@)
	@sim.sh $(dir $<) > $@ 2>&1

