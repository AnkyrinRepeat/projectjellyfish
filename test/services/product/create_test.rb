require 'test_helper'

class Product::CreateTest < ActiveSupport::TestCase
  setup do
    @product_type = product_types :cloud_forms_automation
    @provider = providers :cloud_forms
    @settings = { miq_namespace: 'namespace', miq_class: 'class', miq_instance: 'instance' }
    @attributes = {
      product_type_id: @product_type.id,
      provider_id: @provider.id,
      name: 'Test Product',
      description: 'Test description',
      setup_price: '1.99',
      hourly_price: '0.009',
      monthly_price: '99.99',
      properties: [],
      settings: @settings,
      tag_list: %w(one two)
    }
  end

  test 'should create a product' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes } }
    result = Product::Create.run(context: context, params: params)

    assert_equal true, result.valid?
    product = Product.find result.model.id
    assert_equal CloudForms::Automation::Product, product.class
    assert_equal 'CloudForms::Automation::Product', product.type
    assert_equal 'cloud_forms/automation/product', product.type_name
    assert_equal 'Test Product', product.name
    assert_equal 'Test description', product.description
    assert_equal BigDecimal('1.99'), product.setup_price
    assert_equal BigDecimal('0.009'), product.hourly_price
    assert_equal BigDecimal('99.99'), product.monthly_price
    assert_equal %w(one two), product.tag_list
  end

  test 'should not create a product with an invalid product type' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.merge(product_type_id: SecureRandom.uuid) } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Record Not Found', error.title
    assert_equal '/data/attributes/product_type_id', error.source[:pointer]
  end

  test 'should not create a product with an invalid provider' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.merge(provider_id: SecureRandom.uuid) } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/provider_id', error.source[:pointer]
  end

  test 'should deny non-managers' do
    user = users :user

    context = user
    params = { data: { type: 'products', attributes: @attributes } }
    assert_raises Goby::Service::NotAuthorizedError do
      Product::Create.run(context: context, params: params)
    end
  end


  test 'should require a name' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.tap { |attrib| attrib.delete :name } } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/name', error.source[:pointer]
  end

  test 'should require settings' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.tap { |attrib| attrib.delete :settings } } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/settings', error.source[:pointer]
  end

  test 'should require settings to be a hash' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.merge(settings: ['wrong']) } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/settings', error.source[:pointer]
  end


  test 'should allow description to be optional' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.tap { |attrib| attrib.delete :description } } }
    result = Product::Create.run(context: context, params: params)

    assert_equal true, result.valid?
  end

  test 'should require description to be a string' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.merge(description: ['wrong']) } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/description', error.source[:pointer]
  end

  test 'should require tag_list to be an array' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.merge(tag_list: {wrong: 'wrong'}) } }
    result = Product::Create.run(context: context, params: params)

    assert_equal false, result.valid?
    assert_equal 1, result.errors.length
    error = result.errors.first
    assert_equal 'Validation Error', error.title
    assert_equal '/data/attributes/tag_list', error.source[:pointer]
  end

  test 'should allow tag_list to be optional' do
    user = users :manager

    context = user
    params = { data: { type: 'products', attributes: @attributes.tap { |attrib| attrib.delete :tag_list } } }
    result = Product::Create.run(context: context, params: params)

    assert_equal true, result.valid?
  end
end
