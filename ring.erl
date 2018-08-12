-module(ring).
-author("truongdm3").

-export([element_by_index/2, start/1, stop/1, begin_ring_transfer/1, coordinator_func/2, process_in_ring/1]).

reverse([]) ->
    [];
reverse([Head | Rest]) ->
    reverse(Rest) ++ [Head].

% num_of_elements([]) ->
%     0;
% num_of_elements([_ | Rest]) -> 
%     1 + num_of_elements((Rest)).

element_by_index([Head | _], 1) ->
    Head;
element_by_index([_ | Rest], N) ->
    element_by_index(Rest, N-1).

start(Num_of_processes) ->
    Process_list = reverse(create_ring(Num_of_processes)),
    register(coordinator, spawn(?MODULE, coordinator_func, [Process_list, Num_of_processes])),
    Process_list.

begin_ring_transfer(Process_list) ->
    First_element_in_ring = element_by_index(Process_list, 1),
    First_element_in_ring ! the_master_has_spoken.

stop(Process_list) ->
    lists:map(fun(Process) -> Process ! time_to_sleep end, Process_list),
    coordinator ! time_to_sleep,
    and_thus_the_ring_reaches_its_end.

create_ring(0) ->
    [];
create_ring(N) ->
    [spawn(?MODULE, process_in_ring, [N]) | create_ring(N-1)].

coordinator_func(Process_list, Num_of_processes) ->
    receive
        {Pid, N, where_is_my_next} ->
            if 
                N == Num_of_processes ->
                    N1 = 1;
                true ->
                    N1 = N + 1
            end,
            Next = element_by_index(Process_list, N1),
            Pid ! {Next, N1, this_is_your_next},
            coordinator_func(Process_list, Num_of_processes);
        time_to_sleep ->
            ok
    end.

process_in_ring(N) ->
    receive
        the_master_has_spoken ->
            io:format("Let the battle begins ~n"),
            coordinator ! {self(), N, where_is_my_next},
            ?MODULE: process_in_ring(N);
        {Prev, Prev_index, message} ->
            io:format("Process ~w(~w) received a message from process ~w(~w)~n", [N, self(), Prev_index, Prev]),
            % io:format("CODE UPGRADE 1~n"),
            if
                N == 1 ->
                    ring_transfer_complete,
                    ?MODULE: process_in_ring(N);
                true ->
                    coordinator ! {self(), N, where_is_my_next},
                    ?MODULE: process_in_ring(N)
            end;
        {Next, N1, this_is_your_next} ->
            io:format("Process ~w(~w) sending a message to process ~w(~w)~n", [N, self(), N1, Next]),
            % io:format("CODE UPGRADE 2~n"),
            Next ! {self(), N, message},
            ?MODULE: process_in_ring(N);
        time_to_sleep ->
            ok
    end.

% Run:
% c(ring).
% Process_list = ring:start(5).
% ring:begin_ring_transfer(Process_list).
% ring:begin_ring_transfer(Process_list).
% ring:stop(Process_list).