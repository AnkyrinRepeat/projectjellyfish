require 'test_helper'

class ProductCategory::SearchTest < ActiveSupport::TestCase
  setup do
    @user = users :user

    @context = @user
    @params = {}
  end

  test 'should get all product categories' do
    result = ProductCategory::Search.run(context: @context, params: @params)

    assert result.valid?
    assert_equal ProductCategory.count, result.model.length
  end

  test 'should get sorted results by default' do
    result = ProductCategory::Search.run(context: @context, params: @params)

    assert result.valid?
    product_category = ProductCategory.order(name: :asc).first
    assert_equal product_category.name, result.model.first.name
  end

  test 'should allow reverse sorting' do
    result = ProductCategory::Search.run(context: @context, params: { sort: {name: :desc} })

    assert result.valid?
    product_categories = ProductCategory.order(name: :desc).all
    assert_equal product_categories.first.name, result.model.first.name
    assert_equal product_categories.last.name, result.model.last.name
  end

  test 'should allow sorting by multiple attributes' do
    result = ProductCategory::Search.run(context: @context, params: { sort: {name: :desc, updated_at: :asc} })

    assert result.valid?
    product_categories = ProductCategory.order(name: :desc, updated_at: :asc).all
    assert_equal product_categories.first.name, result.model.first.name
    assert_equal product_categories.last.name, result.model.last.name
  end
end
