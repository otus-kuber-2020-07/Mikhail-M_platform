#!/usr/bin/env bash
helm repo add --username admin --password Harbor12345 templating https://harbor.34.123.40.46.nip.io/chartrepo
helm push --username admin --password Harbor12345 frontend/ templating
helm push --username admin --password Harbor12345 hipster-shop/ templating
