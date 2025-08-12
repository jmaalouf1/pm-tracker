/* eslint-disable no-unused-vars */
const Service = require('./Service');

/**
* Create a new project
*
* project Project  (optional)
* no response value expected for this operation
* */
const projectsPOST = ({ project }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        project,
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
  projectsPOST,
};
