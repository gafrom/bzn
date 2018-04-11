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
                 when 'no_properties'
                    Product.available
                           .where.not(id: with_both_types_of_properties)
                           .limit(MAX_ITEMS)
                 end
  end

  def with_both_types_of_properties
    with_length_property_and_not_dresses & with_other_properties
  end

  def with_other_properties
    Product.available.includes(:properties)
           .where(properties: { name: %w[Выходная Повседневная Домашняя] })
           .pluck(:id)
  end

  def with_length_property_and_not_dresses
    Product.available.includes(:properties)
           .where(properties: { name: %w[Мини Миди Макси] })
           .pluck(:id) |
    Product.available.includes(:properties)
           .where.not(category_id: 3)
           .pluck(:id)
  end
end
