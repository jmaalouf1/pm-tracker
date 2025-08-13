/* eslint-disable no-unused-vars */
const Service = require('./Service');

/**
* List all customers
*
* no response value expected for this operation
* */
const customersGET = () => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Invalid input',
        e.status || 405,
      ));
    }
  },
);
/**
* Create a new customer
*
* customer Customer  (optional)
* no response value expected for this operation
* */
const customersPOST = ({ customer }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        customer,
      }));
    } catch (e) {
      reject(Service.rejectResponse(
        e.message || 'Invalid input',
        e.status || 405,
      ));
    }
  },
);

module.exports = {
  customersGET,
  customersPOST,
};
