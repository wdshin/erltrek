%%% --------------------------------------------------------------------
%%% BSD 3-clause license:
%%%
%%% Copyright (c) 2014, Andreas Stenius <kaos@astekk.se>
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions
%%% are met:
%%%
%%% 1. Redistributions of source code must retain the above copyright
%%% notice, this list of conditions and the following disclaimer.
%%%
%%% 2. Redistributions in binary form must reproduce the above
%%% copyright notice, this list of conditions and the following
%%% disclaimer in the documentation and/or other materials provided
%%% with the distribution.
%%%
%%% 3. Neither the name of the copyright holder nor the names of its
%%% contributors may be used to endorse or promote products derived
%%% from this software without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
%%% CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
%%% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
%%% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%%% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
%%% BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
%%% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
%%% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
%%% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
%%% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
%%% TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
%%% THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
%%% SUCH DAMAGE.
%%% --------------------------------------------------------------------

-module(erltrek_sup).
-behaviour(supervisor).
-include("erltrek.hrl").

-export([start_link/0, init/1]).

-spec start_link() -> startlink_ret().

start_link() ->
    supervisor:start_link(?MODULE, []).

-spec init(Args :: term()) ->
        {ok, {{RestartStrategy :: supervisor:strategy(),
               MaxR            :: non_neg_integer(),
               MaxT            :: non_neg_integer()},
               [ChildSpec :: supervisor:child_spec()]}} | ignore.

init(_Args) ->
    RestartStrategy = one_for_all,
    MaxRestarts = 1,
    MaxTime = 60,
    %% NOTE: the supervisor starts the children from top to bottom in this list
    %% So, children with dependencies must be listed after those they depend on.
    Childs = [{events,
               {erltrek_event, start_link,
                %% TODO: make this configurable by
                %% placing it in the app enviorment or some such..
                [[{erltrek_terminal, []}]]},
               permanent, brutal_kill, worker, dynamic},

              {ships,
               {erltrek_ship_sup, start_link, []},
               permanent, 5000, supervisor, [erltrek_ship_sup]},

              {galaxy, %% depends on 'ships' supervisor
               {erltrek_galaxy, start_link, []},
               permanent, 5000, worker, [erltrek_galaxy]},

              %% start game last, so everything else is in place when we get there
              {game,
               {erltrek_game, start_link, []},
               permanent, 60000, worker, [erltrek_game]}
             ],
    {ok, {{RestartStrategy, MaxRestarts, MaxTime}, Childs}}.
