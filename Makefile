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
	@echo "Cleaning up..."
	rm -rf $(PLUGIN_DIR)/*

.PHONY: all install-all install-single install-multiple clean