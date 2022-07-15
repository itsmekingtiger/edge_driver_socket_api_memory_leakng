

all: package publish install

package:
	@echo '==================== package ===================='
	smartthings edge:drivers:package .
	@echo
	@echo

publish:
	@echo '==================== publish ===================='
	smartthings edge:drivers:publish
	@echo
	@echo

install:
	@echo '==================== install ===================='
	smartthings edge:drivers:install
	@echo
	@echo

vet:
	smartthings edge:drivers:package -b /dev/null

release: package publish