'use strict';

var _ = require('lodash');

/**@ngInject*/
function CreateProductController(product) {
  this.product = product;
}

CreateProductController.resolve = {
  /**@ngInject*/
  product: function(ProductsResource, $stateParams) {
    return new ProductsResource($stateParams);
  }
};

module.exports = CreateProductController;


