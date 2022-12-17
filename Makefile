install: src/macism.swift
	[ -d bin ] || mkdir bin
	swiftc src/macism.swift -o bin/macism