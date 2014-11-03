-module(registry).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_statem.hrl").
-compile(export_all).

-record(state,{pids=[],regs=[]}).

initial_state() ->
  #state{}.

%% spawn

spawn_args(_) ->
  [].

spawn() ->
  erlang:spawn(timer,sleep,[5000]).

spawn_next(S,Pid,[]) ->
  S#state{pids=S#state.pids++[Pid]}.

%% register

register_args(S) ->
  [name(),pid(S)].

-define(names,[a,b,c,d,e]).

name() ->
  elements(?names).

pid(S) ->
  elements(S#state.pids).

register(Name,Pid) ->
  erlang:register(Name,Pid).

register_pre(S) ->
  S#state.pids /= [].

register_pre(S,[Name,Pid]) ->
  not lists:keymember(Name,1,S#state.regs) andalso
  not lists:keymember(Pid, 2,S#state.regs).

register_next(S,_,[Name,Pid]) ->
  S#state{regs=S#state.regs++[{Name,Pid}]}.

%% whereis

whereis_args(_) ->
  [name()].

whereis(Name) ->
  erlang:whereis(Name).

whereis_post(S,[Name],Res) ->
  eq(Res,proplists:get_value(Name,S#state.regs)).

prop_registry() ->
  ?FORALL(Cmds, commands(?MODULE),
          begin
            [catch unregister(Name) || Name <- ?names],
            {H, S, Res} = run_commands(?MODULE,Cmds),
            pretty_commands(?MODULE, Cmds, {H, S, Res},
                            aggregate(command_names(Cmds),
                                      Res == ok))
          end).
