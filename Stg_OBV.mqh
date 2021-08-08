/**
 * @file
 * Implements OBV strategy based on the On Balance Volume indicator.
 */

// User input params.
INPUT_GROUP("OBV strategy: strategy params");
INPUT float OBV_LotSize = 0;                // Lot size
INPUT int OBV_SignalOpenMethod = 2;         // Signal open method (-127-127)
INPUT float OBV_SignalOpenLevel = 0.0f;     // Signal open level
INPUT int OBV_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int OBV_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int OBV_SignalCloseMethod = 2;        // Signal close method (-127-127)
INPUT float OBV_SignalCloseLevel = 0.0f;    // Signal close level
INPUT int OBV_PriceStopMethod = 1;          // Price stop method
INPUT float OBV_PriceStopLevel = 0;         // Price stop level
INPUT int OBV_TickFilterMethod = 1;         // Tick filter method
INPUT float OBV_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short OBV_Shift = 0;                  // Shift
INPUT int OBV_OrderCloseTime = -20;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("OBV strategy: OBV indicator params");
INPUT ENUM_APPLIED_PRICE OBV_Indi_OBV_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int OBV_Indi_OBV_Shift = 0;                                   // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_OBV_Params_Defaults : OBVParams {
  Indi_OBV_Params_Defaults() : OBVParams(::OBV_Indi_OBV_Applied_Price, ::OBV_Indi_OBV_Shift) {}
} indi_obv_defaults;

// Defines struct with default user strategy values.
struct Stg_OBV_Params_Defaults : StgParams {
  Stg_OBV_Params_Defaults()
      : StgParams(::OBV_SignalOpenMethod, ::OBV_SignalOpenFilterMethod, ::OBV_SignalOpenLevel,
                  ::OBV_SignalOpenBoostMethod, ::OBV_SignalCloseMethod, ::OBV_SignalCloseLevel, ::OBV_PriceStopMethod,
                  ::OBV_PriceStopLevel, ::OBV_TickFilterMethod, ::OBV_MaxSpread, ::OBV_Shift, ::OBV_OrderCloseTime) {}
} stg_obv_defaults;

// Struct to define strategy parameters to override.
struct Stg_OBV_Params : StgParams {
  OBVParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_OBV_Params(OBVParams &_iparams, StgParams &_sparams)
      : iparams(indi_obv_defaults, _iparams.tf.GetTf()), sparams(stg_obv_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_OBV : public Strategy {
 public:
  Stg_OBV(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_OBV *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    OBVParams _indi_params(indi_obv_defaults, _tf);
    StgParams _stg_params(stg_obv_defaults);
#ifdef __config__
    SetParamsByTf<OBVParams>(_indi_params, _tf, indi_obv_m1, indi_obv_m5, indi_obv_m15, indi_obv_m30, indi_obv_h1,
                             indi_obv_h4, indi_obv_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_obv_m1, stg_obv_m5, stg_obv_m15, stg_obv_m30, stg_obv_h1, stg_obv_h4,
                             stg_obv_h8);
#endif
    // Initialize indicator.
    OBVParams obv_params(_indi_params);
    _stg_params.SetIndicator(new Indi_OBV(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_OBV(_stg_params, _tparams, _cparams, "OBV");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_OBV *_indi = GetIndicator();
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncreasing(2, 0, _shift);
        _result &= _indi.IsIncByPct(_level, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecreasing(2, 0, _shift);
        _result &= _indi.IsDecByPct(-_level, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
