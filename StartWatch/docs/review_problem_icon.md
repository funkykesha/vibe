Корень: macOS (точнее macOS 26 / PyObjC) перестал показывать NSStatusItem в процессе с .accessory activation policy, если иконка создавалась      
  внутри главного процесса.                                                                                                                         
                                                                                                                                                    
  Что пробовали по шагам:                                                                                                                           
                                                                                                                                                    
  1. Python/rumps эра — NSStatusItem в главном процессе. Иконка пропадала при некоторых условиях macOS 26.                                          
  2. Swift rewrite — переписали всё на Swift с .accessory policy (без Dock-иконки). Та же проблема — NSStatusItem внутри daemon-процесса не
  появлялся в меню баре.                                                                                                                            
  3. Решение — два бинарника: WorkGuard (главный daemon, без иконки) + WorkGuardMenu (отдельный .accessory агент, только NSStatusItem). Главный   
  спавнит WorkGuardMenu при старте через launchMenuAgent().                                                                                         
                                                                                                                                                  
  Почему это работает: macOS надёжно показывает NSStatusItem только в процессе, который является full UI agent — отдельный бинарник с собственным   
  NSApplication цикл.                                                                                                                             
                                                                                                                                                    
  IPC между ними: файлы status.json / command.json в ~/.config/work_guard/, атомарный запись через tmp-rename.  