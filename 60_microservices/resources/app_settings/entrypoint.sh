#!/bin/sh

rails db:migrate:reset

rails s -b '0.0.0.0'

