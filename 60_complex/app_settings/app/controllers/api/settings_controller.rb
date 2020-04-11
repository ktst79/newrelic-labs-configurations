class Api::SettingsController < ApplicationController
    def index
        @settings = Setting.all
    end
end
