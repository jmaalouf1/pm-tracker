/* eslint-disable no-unused-vars */
const Service = require('./Service');

/**
* Change password (e.g., first login)
*
* authChangePasswordPostRequest AuthChangePasswordPostRequest  (optional)
* no response value expected for this operation
* */
const authChangePasswordPOST = ({ authChangePasswordPostRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        authChangePasswordPostRequest,
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
* User login to obtain JWT tokens
*
* authLoginPostRequest AuthLoginPostRequest 
* no response value expected for this operation
* */
const authLoginPOST = ({ authLoginPostRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        authLoginPostRequest,
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
* Refresh access token
*
* authRefreshPostRequest AuthRefreshPostRequest 
* no response value expected for this operation
* */
const authRefreshPOST = ({ authRefreshPostRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        authRefreshPostRequest,
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
  authChangePasswordPOST,
  authLoginPOST,
  authRefreshPOST,
};
