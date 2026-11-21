extends SceneTree

func _initialize() -> void:
 assert(WorldGenerator.city_size(1200)=="Pequeña")
 assert(WorldGenerator.city_size(6200)=="Mediana")
 assert(WorldGenerator.city_size(15000)=="Grande")
 var low := GameState.new(1)
 low.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":4,"y":0,"population":1000,"completed":{}}]
 low._generate_demand(1.0)
 var high := GameState.new(1)
 high.cities = [{"name":"A","x":0,"y":0,"population":12000,"completed":{}},{"name":"B","x":4,"y":0,"population":1000,"completed":{}}]
 high._generate_demand(1.0)
 assert(high.potential_demand > low.potential_demand)
 assert(is_equal_approx(float(high.demand_credit["0:1"]),float(high.demand_credit["1:0"])))
 assert(not low.unlock_reason(2).is_empty())
 low.roads = [{"id":9,"path":[[0,0],[1,0],[2,0],[3,0],[4,0]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 low.completed = 10
 assert(low.unlock_reason(2).is_empty())
 low.money = 1000.0
 assert(low.take_loan())
 assert(not low.take_loan())
 var loan_copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(low.data())))
 assert(is_equal_approx(loan_copy.loan_remaining,Balance.LOAN_TOTAL))
 loan_copy._pay_loan_installment()
 assert(is_equal_approx(loan_copy.loan_remaining,Balance.LOAN_TOTAL-Balance.LOAN_DAILY_PAYMENT))
 var state := GameState.new(2)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":1,"y":0,"population":1000,"completed":{}}]
 state.roads = [{"id":1,"path":[[0,0],[1,0]],"type":6,"length":1.0,"work":0.0,"condition":100.0,"speed_limit":120.0,"trips":0,"toll":25.0}]
 state.spawn_clock = -1000.0
 assert(state._start_trip(0,1))
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(float(copy.vehicles[0].toll_due)==25.0)
 copy.step(0.25)
 assert(copy.completed==1 and is_equal_approx(copy.income,143.0))
 assert(is_equal_approx(copy.toll_income,25.0))
 var earned: float = copy.income
 copy.step(0.25)
 assert(is_equal_approx(copy.income,earned))
 var contract_state := GameState.new(3)
 contract_state.cities = state.cities.duplicate(true)
 contract_state.offer_contract(0,1)
 contract_state.accept_contract()
 contract_state.roads = state.roads.duplicate(true)
 var contract_copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(contract_state.data())))
 contract_copy._update_contract()
 assert(contract_copy.contract.status=="completed" and contract_copy.contracts_completed==1)
 assert(is_equal_approx(contract_copy.contract_income,float(contract_copy.contract.reward)))
 var reward: float = contract_copy.income
 contract_copy._update_contract()
 assert(is_equal_approx(contract_copy.income,reward))
 print("ECONOMY OK: tamaño, demanda, préstamo, peaje y contrato")
 quit()
