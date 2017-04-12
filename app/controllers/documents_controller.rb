# encoding:UTF-8
class DocumentsController < ApplicationController
  load_permissions_and_authorize_resource

  def index
    @documents = filter_documents(@documents, params[:category])
    grid = initialize_grid(@documents, order: 'documents.updated_at',
                                       order_direction: 'desc')

    @documents = DocumentView.new(grid: grid,
                                  categories: Document.categories,
                                  current_category: params[:category])
  end

  def show
    document = Document.find(params[:id])
    redirect_to document.view
  end

  private

  def filter_documents(documents, category)
    if category.present?
      documents.where(category: category)
    else
      documents
    end
  end
end
