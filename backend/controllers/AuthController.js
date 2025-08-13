/**
 * The AuthController file is a very simple one, which does not need to be changed manually,
 * unless there's a case where business logic routes the request to an entity which is not
 * the service.
 * The heavy lifting of the Controller item is done in Request.js - that is where request
 * parameters are extracted and sent to the service, and where response is handled.
 */

const Controller = require('./Controller');
const service = require('../services/AuthService');
const authChangePasswordPOST = async (request, response) => {
  await Controller.handleRequest(request, response, service.authChangePasswordPOST);
};

const authLoginPOST = async (request, response) => {
  await Controller.handleRequest(request, response, service.authLoginPOST);
};

const authRefreshPOST = async (request, response) => {
  await Controller.handleRequest(request, response, service.authRefreshPOST);
};


module.exports = {
  authChangePasswordPOST,
  authLoginPOST,
  authRefreshPOST,
};
