/**
 * Flow 1 "Shop — Create Order" · Run Script operation · key: `respond_existing`
 *
 * Terminal operation on the Condition's REJECT branch — the path taken when
 * `plan` found the order already on file. No gateway call happens here; `plan`
 * has already built the whole response.
 *
 * Expects: plan (Run Script)
 */
module.exports = async function (data) {
  return (data.plan && data.plan.response) || {};
};
