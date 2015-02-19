require_dependency "push_type/admin_controller"

module PushType
  class NodesController < AdminController

    before_filter :build_node,  only: [:new, :create]
    before_filter :load_node,   only: [:edit, :update, :destroy, :restore, :position]

    def index
      @nodes = node_scope.not_trash.page(params[:page]).per(30)
    end

    def trashed
      @nodes = PushType::Node.all.trashed.page(params[:page]).per(30).reorder(deleted_at: :desc)
    end

    def new
    end

    def create
      if @node.save
        flash[:notice] = "#{ @node.type } successfully created."
        redirect_to redirect_path
      else
        render 'new'
      end
    end

    def edit
    end

    def update
      if @node.update_attributes node_params.merge(updater: push_type_user)
        flash[:notice] = "#{ @node.type } successfully updated."
        redirect_to redirect_path
      else
        render 'edit'
      end
    end

    def destroy
      if @node.trashed?
        @node.destroy
        flash[:notice] = "#{ @node.type } permanently deleted."
        redirect_to redirect_path
      else
        @node.trash!
        flash[:notice] = "#{ @node.type } trashed."
        redirect_to redirect_path(true)
      end
    end

    def position
      if reorder_node
        head :ok
      else
        render json: @node.errors, status: :unprocessable_entity
      end
    end

    def restore
      @node.restore!
      flash[:notice] = "#{ @node.type } successfully restored."
      redirect_to redirect_path
    end

    def empty
      PushType::Node.trashed.destroy_all
      flash[:notice] = "Trash successfully emptied."
      redirect_to push_type.nodes_path
    end

    private

    def node_scope
      @node_scope ||= if params[:node_id]
        @parent = PushType::Node.find params[:node_id]
        @parent.children
      else
        PushType::Node.roots
      end
    end

    def build_node
      @node = node_scope.new type: params[:kind].camelcase, creator: push_type_user, updater: push_type_user
      @node.attributes = @node.attributes.merge(node_params)
    end

    def load_node
      @node = PushType::Node.find params[:id]
    end

    def node_params
      fields = [:title, :slug, :status, :published_at, :published_to] + @node.field_params
      params.fetch(@node.type.underscore.to_sym, {}).permit(*fields)
    end

    def redirect_path(skip_trash = false)
      if @node.trashed? && !skip_trash
        push_type.trashed_nodes_path
      elsif @node.root?
        push_type.nodes_path
      else
        push_type.node_nodes_path(@node.parent_id)
      end
    end

    def initial_breadcrumb
      breadcrumbs.add 'Content', push_type.nodes_path
    end

    def reorder_node
      if params[:prev]
        PushType::Node.find(params[:prev]).append_sibling(@node)
      elsif params[:next]
        PushType::Node.find(params[:next]).prepend_sibling(@node)
      end
    end
    
  end
end
