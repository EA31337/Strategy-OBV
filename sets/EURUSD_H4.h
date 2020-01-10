//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_OBV_EURUSD_H4_Params : Stg_OBV_Params {
  Stg_OBV_EURUSD_H4_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H4;
    OBV_Period = 2;
    OBV_Applied_Price = 3;
    OBV_Shift = 0;
    OBV_TrailingStopMethod = 6;
    OBV_TrailingProfitMethod = 11;
    OBV_SignalOpenLevel = 36;
    OBV_SignalBaseMethod = 0;
    OBV_SignalOpenMethod1 = 1;
    OBV_SignalOpenMethod2 = 0;
    OBV_SignalCloseLevel = 36;
    OBV_SignalCloseMethod1 = 1;
    OBV_SignalCloseMethod2 = 0;
    OBV_MaxSpread = 10;
  }
};
