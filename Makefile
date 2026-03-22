# Variables
PLUGIN_DIR = $(HOME)/.local/lib/wireshark/plugins
CJSON = $(HOME)/.local/lib/wireshark/plugins/cjson 
JSON = $(HOME)/.local/lib/wireshark/plugins/jsonschema 
NET = $(HOME)/.local/lib/wireshark/plugins/net
FILES = jsonschema.lua 
MULTIPLE_FILES = separate/ocpp16Dissector.lua separate/ocpp20Dissector.lua separate/ocpp201Dissector.lua
SINGLE_FILE = ocppDissector.lua

# Default target
all:
	@echo "Use 'make install-single' or 'make install-multiple' to install the dissector."

# Install target for single option
install-single:
	@echo "Installing single dissector file..."
	mkdir -p $(PLUGIN_DIR)
	mkdir -p $(CJSON)
	cp cjson/util.lua $(CJSON)
	mkdir -p $(JSON)
	cp jsonschema/store.lua $(JSON)
	mkdir -p $(NET)
	cp net/url.lua $(NET)
	cp $(FILES) $(PLUGIN_DIR)
	cp $(SINGLE_FILE) $(PLUGIN_DIR)

# Install target for multiple option
install-multiple:
	@echo "Installing multiple dissector files..."
	mkdir -p $(PLUGIN_DIR)
	mkdir -p $(CJSON)
	cp cjson/util.lua $(CJSON)
	mkdir -p $(JSON)
	cp jsonschema/store.lua $(JSON)
	mkdir -p $(NET)
	cp net/url.lua $(NET)
	cp $(FILES) $(PLUGIN_DIR)
	cp $(MULTIPLE_FILES) $(PLUGIN_DIR)

# Clean target
clean:
	@echo "Cleaning only files installed by this Makefile..."

	# Remove single dissector (if installed)
	rm -f $(PLUGIN_DIR)/$(SINGLE_FILE)

	# Remove multiple dissectors (if installed)
	rm -f $(addprefix $(PLUGIN_DIR)/,$(notdir $(MULTIPLE_FILES)))

	# Remove shared lua file
	rm -f $(PLUGIN_DIR)/$(FILES)

	# Remove copied dependency files
	rm -f $(CJSON)/util.lua
	rm -f $(JSON)/store.lua
	rm -f $(NET)/url.lua

	# Remove directories only if empty
	rmdir --ignore-fail-on-non-empty $(CJSON) 2>/dev/null || true
	rmdir --ignore-fail-on-non-empty $(JSON) 2>/dev/null || true
	rmdir --ignore-fail-on-non-empty $(NET) 2>/dev/null || true

.PHONY: all install-all install-single install-multiple clean