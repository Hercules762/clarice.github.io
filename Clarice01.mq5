//+------------------------------------------------------------------+
//|                                                    Clarice01.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input int fastPeriod = 10; // Período da SMA curta
input int slowPeriod = 50; // Período da SMA longa
input double lotSize = 0.01; // Tamanho do lote
input ENUM_TIMEFRAMES timeframe = PERIOD_M30; // Timeframe (intervalo de tempo)

double trailingStart = 0; // Preço a partir do qual o Trailing Stop será ativado
double trailingStopDistance = 50 * Point; // Distância para o Trailing Stop em pontos
int maxCandleRange = 1000 * Point; // Máxima faixa de vela em pontos para confirmação

void OnTick()
{
    if (TimeFrame != timeframe) // Verifica se o intervalo de tempo é o desejado
        return;

    double fastMA = iMA(NULL, 0, fastPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);
    double slowMA = iMA(NULL, 0, slowPeriod, 0, MODE_SMA, PRICE_CLOSE, 0);

    double candleRange = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * MarketInfo(_Symbol, MODE_SPREAD);

    if (fastMA > slowMA && candleRange <= maxCandleRange)
    {
        // Condição de compra
        double openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // Calcular os níveis de take profit e stop loss
        double takeProfitPrice = openPrice + 150 * Point;
        double stopLossPrice = openPrice - 50 * Point;

        // Colocar a ordem de compra
        int ticket = OrderSend(_Symbol, OP_BUY, lotSize, openPrice, 3, stopLossPrice, takeProfitPrice, "Buy Order", 0, clrNONE);

        if (ticket > 0)
        {
            trailingStart = openPrice + trailingStopDistance;
        }
    }
    else if (fastMA < slowMA && candleRange <= maxCandleRange)
    {
        // Condição de venda
        double openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        // Calcular os níveis de take profit e stop loss
        double takeProfitPrice = openPrice - 150 * Point;
        double stopLossPrice = openPrice + 50 * Point;

        // Colocar a ordem de venda
        int ticket = OrderSend(_Symbol, OP_SELL, lotSize, openPrice, 3, stopLossPrice, takeProfitPrice, "Sell Order", 0, clrNONE);

        if (ticket > 0)
        {
            trailingStart = openPrice - trailingStopDistance;
        }
    }

    // Verificar e atualizar o Trailing Stop
    if (trailingStart > 0)
    {
        if (OrderType() == OP_BUY && Bid - trailingStart > trailingStopDistance)
        {
            double newTrailingStop = Bid - trailingStopDistance;
            OrderModify(OrderTicket(), OrderOpenPrice(), newTrailingStop, OrderTakeProfit(), 0, clrNONE);
            trailingStart = newTrailingStop;
        }
        else if (OrderType() == OP_SELL && trailingStart - Ask > trailingStopDistance)
        {
            double newTrailingStop = Ask + trailingStopDistance;
            OrderModify(OrderTicket(), OrderOpenPrice(), newTrailingStop, OrderTakeProfit(), 0, clrNONE);
            trailingStart = newTrailingStop;
        }
    }
}
