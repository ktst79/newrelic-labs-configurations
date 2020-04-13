#!/bin/sh

newrelic install --force --license_key="${NR_LICENSEKEY}" "${NR_APP_NAME}"

rails s -b '0.0.0.0'

