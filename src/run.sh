#!/bin/bash

set -euo pipefail

gem install nokogiri --quiet --silent

ruby junit.rb /junits/*
