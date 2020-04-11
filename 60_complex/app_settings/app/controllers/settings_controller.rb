class SettingsController < ApplicationController
    def index
        @settings = Setting.all        
    end
    
    def new
        @setting = Setting.new
    end

    def create
        @setting = Setting.new(setting_params)

        if @setting.save
            redirect_to settings_path
        else
            render 'new'
        end
    end

    def edit
        @setting = Setting.find(params[:id])
    end
    
    def show
        @setting = Setting.find(params[:id])
    end

    def destroy
        @setting = Setting.find(params[:id])
        @setting.destroy
       
        redirect_to settings_path
    end

    private
        def setting_params
            params.require(:setting).permit(:key, :url)
        end
end
