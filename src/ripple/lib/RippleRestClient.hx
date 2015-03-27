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
  balances: Array<{currency: String, counterparty: String, value: String}>,
  ?error_type: String,
  ?error: String,
  ?message: String
}
