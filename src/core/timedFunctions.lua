return function (clock, client, statusTable, slashHandler)
  clock:on("min", function()
    client:setActivity(statusTable[math.random(#statusTable)]);
  end)

  clock:on("hour", function(now)
    if now.hour == 18 then
      slashHandler["tsihoclock"].executeWithTimer(client);
    end
  end)
end
