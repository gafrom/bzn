class Admin::ProductsController < AdminController
  MAX_ITEMS = 15

  before_action :set_resources, only:   :index
  before_action :set_resource,  except: :index

  def index; end

  def edit; end

  def update
    @resource.update permit_params
    redirect_to [:edit, :admin, @resource], notice: I18n.t(:updated_success)
  end

  private

  def permit_params
    params.require(:product).permit(:color, :length, property_ids: [], color_ids: [])
  end

  def set_resource
    @resource = Product.find params[:id]
  end

  def set_resources
    @resources = case params[:filter_in]
                 when 'no_color'
                   Product.available
                          .joins('left join colorations on colorations.product_id = products.id')
                          .where('colorations.color_id is null').where.not(supplier_id: 10)
                          .limit(MAX_ITEMS)
                 when 'no_length'
                   Product.available
                          .where(category_id: 3)
                          .includes(:propertings)
                          .where(propertings: { property_id: nil })
                          .limit(MAX_ITEMS)
                 end
  end
end
