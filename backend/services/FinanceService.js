/* eslint-disable no-unused-vars */
const Service = require('./Service');

/**
* Update invoice status or PO flag
*
* projectUnderscoreid String 
* financeProjectIdPatchRequest FinanceProjectIdPatchRequest  (optional)
* no response value expected for this operation
* */
const financeProjectIdPATCH = ({ projectUnderscoreid, financeProjectIdPatchRequest }) => new Promise(
  async (resolve, reject) => {
    try {
      resolve(Service.successResponse({
        projectUnderscoreid,
        financeProjectIdPatchRequest,
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
  financeProjectIdPATCH,
};
