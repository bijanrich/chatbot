module Api
  class MemoriesController < ApplicationController
    # GET /api/memories
    # Returns all memories for testing purposes
    def index
      memories = UserMemory.all
      render json: memories, status: :ok
    end

    # POST /api/memories
    # Creates a new memory
    def create
      user = User.find_or_create_by(email: memory_params[:email]) do |u|
        u.name = memory_params[:name] || 'Anonymous'
      end

      UserMemory.update_facts(user.id, memory_params[:fact])
      render json: { message: 'Memory stored successfully' }, status: :created
    end

    private

    def memory_params
      params.require(:memory).permit(:email, :name, :fact)
    end
  end
end 