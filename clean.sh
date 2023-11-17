#!/bin/bash

# umounting partitions in case last build failed
umount --recursive work/*/stage*/rootfs/{dev,proc,sys} || true

rm -rf work/*
