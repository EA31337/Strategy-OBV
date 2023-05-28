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
INPUT int OBV_SignalOpenFilterTime = 3;     // Signal open filter time
INPUT int OBV_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int OBV_SignalCloseMethod = 2;        // Signal close method (-127-127)
INPUT int OBV_SignalCloseFilter = 0;        // Signal close filter (-127-127)
INPUT float OBV_SignalCloseLevel = 0.0f;    // Signal close level
INPUT int OBV_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float OBV_PriceStopLevel = 2;         // Price stop level
INPUT int OBV_TickFilterMethod = 32;        // Tick filter method
INPUT float OBV_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short OBV_Shift = 0;                  // Shift
INPUT float OBV_OrderCloseLoss = 80;        // Order close loss
INPUT float OBV_OrderCloseProfit = 80;      // Order close profit
INPUT int OBV_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("OBV strategy: OBV indicator params");
INPUT ENUM_APPLIED_PRICE OBV_Indi_OBV_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int OBV_Indi_OBV_Shift = 1;                                   // Shift

// Structs.
// Defines struct with default user strategy values.
struct Stg_OBV_Params_Defaults : StgParams {
  Stg_OBV_Params_Defaults()
      : StgParams(::OBV_SignalOpenMethod, ::OBV_SignalOpenFilterMethod, ::OBV_SignalOpenLevel,
                  ::OBV_SignalOpenBoostMethod, ::OBV_SignalCloseMethod, ::OBV_SignalCloseFilter, ::OBV_SignalCloseLevel,
                  ::OBV_PriceStopMethod, ::OBV_PriceStopLevel, ::OBV_TickFilterMethod, ::OBV_MaxSpread, ::OBV_Shift) {
    Set(STRAT_PARAM_LS, OBV_LotSize);
    Set(STRAT_PARAM_OCL, OBV_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, OBV_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, OBV_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, OBV_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_OBV : public Strategy {
 public:
  Stg_OBV(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_OBV *Init(ENUM_TIMEFRAMES _tf = NULL, EA* _ea = NULL) {
    // Initialize strategy initial values.
    Stg_OBV_Params_Defaults stg_obv_defaults;
    StgParams _stg_params(stg_obv_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_obv_m1, stg_obv_m5, stg_obv_m15, stg_obv_m30, stg_obv_h1, stg_obv_h4,
                             stg_obv_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_OBV(_stg_params, _tparams, _cparams, "OBV");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() {
    IndiOBVParams _indi_params(::OBV_Indi_OBV_Applied_Price, ::OBV_Indi_OBV_Shift);
    _indi_params.SetTf(Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    SetIndicator(new Indi_OBV(_indi_params));
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_OBV *_indi = GetIndicator();
    int _ishift = ::OBV_Indi_OBV_Shift;
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _ishift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _ishift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi.IsIncreasing(2, 0, _ishift);
        _result &= _indi.IsIncByPct(_level, 0, _ishift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi.IsDecreasing(2, 0, _ishift);
        _result &= _indi.IsDecByPct(-_level, 0, _ishift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
