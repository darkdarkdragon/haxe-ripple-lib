package ripple.lib;

import haxe.Http;
import haxe.Json;
import thx.promise.Promise;
import thx.core.Error;

/**
 * ...
 * @author Ivan Tivonenko
 */
class RippleRestClient {

    var serverUrl: String;

    public function new(?serverUrl: String = null) {
        this.serverUrl = serverUrl != null ? serverUrl : 'https://api.ripple.com/';
        this.serverUrl += 'v1';
    }

    public function payments(address: String, ?options: PaymentsOptions): Promise<PaymentsResult> {
        var h = new Http('$serverUrl/accounts/$address/payments');
        if (options != null) {
            this.setParams(h, options);
        }
        return Promise.create(function(resolve : PaymentsResult -> Void, reject : Error -> Void) {
            var status = 0;
            h.onStatus = function(_status: Int) {
                status = _status;
//                trace('got status: $status');
            }
            h.onError = function(emsg) {
                reject(new Error(emsg));
            }
            h.onData = function(data) {
//                trace('got data from ripple payments:');
//                trace(data);
                if (status != 0 && (status < 200 || status >= 400)) {
                    // should not be here
                    return;
                }
                try {
                    var dataObj: PaymentsResult = Json.parse(data);
                    if (!dataObj.success) {
                        reject(new Error(dataObj.error));
                    } else {
                        resolve(dataObj);
                    }
                } catch (e: Dynamic) {
                    reject(new Error(Std.string(e)));
                }
            }
            h.request(false);
        });
    }

    function setParams(h: Http, options: Dynamic) {
        for (n in Reflect.fields(options)) {
            h.setParameter(n, Std.string(Reflect.field(options, n)));
        }
    }

    public function balances(address: String, ?currency: String, ?counterparty: String, ?marker: String, ?limit: Int, ?ledger: String): Promise<BalancesResult> {
        var h = new Http('$serverUrl/accounts/$address/balances');
        if (currency != null) {
            h.setParameter('currency', currency);
        }
        if (counterparty != null) {
            h.setParameter('counterparty', counterparty);
        }
        if (marker != null) {
            h.setParameter('marker', marker);
        }
        if (ledger != null) {
            h.setParameter('ledger', ledger);
        }
        if (limit != null) {
            h.setParameter('limit', limit == -1 ? 'all' : Std.string(limit));
        }
        return Promise.create(function(resolve : BalancesResult -> Void, reject : Error -> Void) {
            var status = 0;
            h.onStatus = function(_status: Int) {
                status = _status;
                trace('got status: $status');
            }
            h.onError = function(emsg) {
                if (status == 404) {
                    reject(new Error('actNotFound'));
                } else {
                    reject(new Error(emsg));
                }
            }
            h.onData = function(data) {
                trace('got data from ripple balances:');
                trace(data);
                if (status != 0 && (status < 200 || status >= 400)) {
                    // should not be here
                    return;
                }
                try {
                    var dataObj: BalancesResult = Json.parse(data);
                    if (!dataObj.success) {
                        reject(new Error(dataObj.error));
                    } else {
                        resolve(dataObj);
                    }
                } catch (e: Dynamic) {
                    reject(new Error(Std.string(e)));
                }
            }
            h.request(false);
        });
    }
}


// actNotFound
typedef BalancesResult = {
    success: Bool,
    marker: String,
    ?limit: Int,
    ledger: Int,
    validated: Bool,
    balances: Array<AmountCounterData>,
    ?error_type: String,
    ?error: String,
    ?message: String
}

typedef PaymentsOptions = {
    ?source_account: String,
    ?destination_account: String,
    ?exclude_failed: Bool,
    ?direction: PaymentDirection,
    ?earliest_first: Bool,
    ?start_ledger: Int,
    ?end_ledger: Int,
    ?results_per_page: Int,
    ?page: Int
}

typedef AmountData = {
    value: String,
    currency: String,
    issuer: String
}

typedef AmountCounterData = {
    value: String,
    currency: String,
    counterparty: String
}

typedef PaymentData = {
    payment: {
        source_account: String,
        source_tag: String,
        source_amount: AmountData,
        source_slippage: String,
        destination_account: String,
        destination_tag: String,
        destination_amount: AmountData,
        invoice_id: String,
        paths: String,
        no_direct_ripple: Bool,
        partial_payment: Bool,
        direction: PaymentDirection,
        result: TransactionResultStatus,
        timestamp: String,
        fee: String,
        source_balance_changes: Array<AmountData>,
        destination_balance_changes: Array<AmountData>,
        order_changes: Array<{
            taker_pays: AmountCounterData,
            taker_gets: AmountCounterData,
            sequence: Int,
            status: String
        }>,
        memos: Array <{
            MemoType: String,
            MemoFormat: String,
            parsed_memo_type: String,
            parsed_memo_format: String
        }>
    },
    client_resource_id: String,
    hash: String,
    ledger: String,
    state: String
}

// "timestamp": "2014-11-18T22:13:00.000Z",
// result tesSUCCESS
typedef PaymentsResult = {
    success: Bool,
    ?payments: Array<PaymentData>,
    ?error_type: String,
    ?error: String,
    ?message: String
}

@:enum
abstract TransactionResultStatus(String) {
  var SUCCESS = 'tesSUCCESS';
  var CLAIM = 'tecCLAIM';
  var NO_AUTH = 'tecNO_AUTH';
  var NO_REGULAR_KEY = 'tecNO_REGULAR_KEY';
}

@:enum
abstract PaymentDirection(String) {
  var INCOMING = 'incoming';
  var OUTGOING = 'outgoing';
  var PASSTHROUGH = 'passthrough';
}
