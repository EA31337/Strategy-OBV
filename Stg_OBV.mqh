/**
 * @file
 * Implements OBV strategy based on the On Balance Volume indicator.
 */

// User input params.
INPUT ENUM_APPLIED_PRICE OBV_Applied_Price = PRICE_CLOSE;  // Applied Price
INPUT int OBV_Shift = 0;                                   // Shift
INPUT int OBV_SignalOpenMethod = 0;                        // Signal open method (0-
INPUT float OBV_SignalOpenLevel = 0.00000000;              // Signal open level
INPUT int OBV_SignalOpenFilterMethod = 0.00000000;         // Signal open filter method
INPUT int OBV_SignalOpenBoostMethod = 0.00000000;          // Signal open boost method
INPUT int OBV_SignalCloseMethod = 0;                       // Signal close method (0-
INPUT float OBV_SignalCloseLevel = 0.00000000;             // Signal close level
INPUT int OBV_PriceLimitMethod = 0;                        // Price limit method
INPUT float OBV_PriceLimitLevel = 0;                       // Price limit level
INPUT float OBV_MaxSpread = 6.0;                           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_OBV.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_OBV_Params : StgParams {
  ENUM_APPLIED_PRICE OBV_Applied_Price;
  int OBV_Shift;
  int OBV_SignalOpenMethod;
  float OBV_SignalOpenLevel;
  int OBV_SignalOpenFilterMethod;
  int OBV_SignalOpenBoostMethod;
  int OBV_SignalCloseMethod;
  float OBV_SignalCloseLevel;
  int OBV_PriceLimitMethod;
  float OBV_PriceLimitLevel;
  float OBV_MaxSpread;

  // Constructor: Set default param values.
  Stg_OBV_Params()
      : OBV_Applied_Price(::OBV_Applied_Price),
        OBV_Shift(::OBV_Shift),
        OBV_SignalOpenMethod(::OBV_SignalOpenMethod),
        OBV_SignalOpenLevel(::OBV_SignalOpenLevel),
        OBV_SignalOpenFilterMethod(::OBV_SignalOpenFilterMethod),
        OBV_SignalOpenBoostMethod(::OBV_SignalOpenBoostMethod),
        OBV_SignalCloseMethod(::OBV_SignalCloseMethod),
        OBV_SignalCloseLevel(::OBV_SignalCloseLevel),
        OBV_PriceLimitMethod(::OBV_PriceLimitMethod),
        OBV_PriceLimitLevel(::OBV_PriceLimitLevel),
        OBV_MaxSpread(::OBV_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_OBV : public Strategy {
 public:
  Stg_OBV(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_OBV *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_OBV_Params _params;
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_OBV_Params>(_params, _tf, stg_obv_m1, stg_obv_m5, stg_obv_m15, stg_obv_m30, stg_obv_h1,
                                    stg_obv_h4, stg_obv_h4);
    }
    // Initialize strategy parameters.
    OBVParams obv_params(_params.OBV_Applied_Price);
    obv_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_OBV(obv_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.OBV_SignalOpenMethod, _params.OBV_SignalOpenLevel, _params.OBV_SignalCloseMethod,
                       _params.OBV_SignalOpenFilterMethod, _params.OBV_SignalOpenBoostMethod,
                       _params.OBV_SignalCloseLevel);
    sparams.SetPriceLimits(_params.OBV_PriceLimitMethod, _params.OBV_PriceLimitLevel);
    sparams.SetMaxSpread(_params.OBV_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_OBV(sparams, "OBV");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_OBV *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR].value[0] > _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR].value[0] < _indi[PREV].value[0];
          if (METHOD(_method, 0))
            _result &= _indi[PREV].value[0] < _indi[PPREV].value[0];  // ... 2 consecutive columns are red.
          if (METHOD(_method, 1))
            _result &= _indi[PPREV].value[0] < _indi[3].value[0];  // ... 3 consecutive columns are red.
          if (METHOD(_method, 2))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are red.
          if (METHOD(_method, 3))
            _result &= _indi[PREV].value[0] > _indi[PPREV].value[0];  // ... 2 consecutive columns are green.
          if (METHOD(_method, 4))
            _result &= _indi[PPREV].value[0] > _indi[3].value[0];  // ... 3 consecutive columns are green.
          if (METHOD(_method, 5))
            _result &= _indi[3].value[0] < _indi[4].value[0];  // ... 4 consecutive columns are green.
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_OBV *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 1: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(_indi.GetAppliedPrice(), _indi.GetLowest(_bar_count));
          break;
        }
      }
      _result += _trail * _direction;
    }
    return (float)_result;
  }
};
