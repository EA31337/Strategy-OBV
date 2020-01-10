//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements OBV strategy based on the On Balance Volume indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_OBV.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __OBV_Parameters__ = "-- OBV strategy params --";  // >>> OBV <<<
INPUT int OBV_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT ENUM_TRAIL_TYPE OBV_TrailingStopMethod = 22;             // Trail stop method
INPUT ENUM_TRAIL_TYPE OBV_TrailingProfitMethod = 1;            // Trail profit method
INPUT ENUM_APPLIED_PRICE OBV_Applied_Price = PRICE_CLOSE;      // Applied Price
INPUT double OBV_SignalOpenLevel = 0.00000000;                 // Signal open level
INPUT int OBV1_SignalBaseMethod = 0;                           // Signal base method (0-
INPUT int OBV1_OpenCondition1 = 0;                             // Open condition 1 (0-1023)
INPUT int OBV1_OpenCondition2 = 0;                             // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT OBV1_CloseCondition = C_OBV_BUY_SELL;  // Close condition for M1
INPUT double OBV_MaxSpread = 6.0;                              // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_OBV_Params : Stg_Params {
  unsigned int OBV_Period;
  ENUM_APPLIED_PRICE OBV_Applied_Price;
  int OBV_Shift;
  ENUM_TRAIL_TYPE OBV_TrailingStopMethod;
  ENUM_TRAIL_TYPE OBV_TrailingProfitMethod;
  double OBV_SignalOpenLevel;
  long OBV_SignalBaseMethod;
  long OBV_SignalOpenMethod1;
  long OBV_SignalOpenMethod2;
  double OBV_SignalCloseLevel;
  ENUM_MARKET_EVENT OBV_SignalCloseMethod1;
  ENUM_MARKET_EVENT OBV_SignalCloseMethod2;
  double OBV_MaxSpread;

  // Constructor: Set default param values.
  Stg_OBV_Params()
      : OBV_Period(::OBV_Period),
        OBV_Applied_Price(::OBV_Applied_Price),
        OBV_Shift(::OBV_Shift),
        OBV_TrailingStopMethod(::OBV_TrailingStopMethod),
        OBV_TrailingProfitMethod(::OBV_TrailingProfitMethod),
        OBV_SignalOpenLevel(::OBV_SignalOpenLevel),
        OBV_SignalBaseMethod(::OBV_SignalBaseMethod),
        OBV_SignalOpenMethod1(::OBV_SignalOpenMethod1),
        OBV_SignalOpenMethod2(::OBV_SignalOpenMethod2),
        OBV_SignalCloseLevel(::OBV_SignalCloseLevel),
        OBV_SignalCloseMethod1(::OBV_SignalCloseMethod1),
        OBV_SignalCloseMethod2(::OBV_SignalCloseMethod2),
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
    switch (_tf) {
      case PERIOD_M1: {
        Stg_OBV_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_OBV_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_OBV_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_OBV_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_OBV_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_OBV_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    OBV_Params adx_params(_params.OBV_Period, _params.OBV_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_OBV);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_OBV(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.OBV_SignalBaseMethod, _params.OBV_SignalOpenMethod1, _params.OBV_SignalOpenMethod2,
                       _params.OBV_SignalCloseMethod1, _params.OBV_SignalCloseMethod2, _params.OBV_SignalOpenLevel,
                       _params.OBV_SignalCloseLevel);
    sparams.SetStops(_params.OBV_TrailingProfitMethod, _params.OBV_TrailingStopMethod);
    sparams.SetMaxSpread(_params.OBV_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_OBV(sparams, "OBV");
    return _strat;
  }

  /**
   * Check if OBV indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double obv_0 = ((Indi_OBV *)this.Data()).GetValue(0);
    double obv_1 = ((Indi_OBV *)this.Data()).GetValue(1);
    double obv_2 = ((Indi_OBV *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        break;
      case ORDER_TYPE_SELL:
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
