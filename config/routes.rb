Rails.application.routes.draw do
  root "games#new"

  resources :games, only: [ :new, :create, :show ] do
    member do
      get :lobby              # Лобби (публичное) — вход для игроков
      post :start_game        # Запуск игры (host only)
      post :reveal_next_round
      post :start_raid
      post :reveal_threat
      post :reveal_raid_system
      post :clear_raid_report
      post :rematch           # Переиграть с теми же игроками
      post :fill_bots         # DEV: заполнить ботами
      post :dev_reveal_all    # DEV: вскрыть все карты
      get :report
      get :board              # Публичная доска (без кнопок)
    end

    resources :players, only: [ :show, :update, :create ] do
      member do
        post :reveal_biology
        post :eliminate
      end
      resources :player_cards, only: [] do
        member do
          post :reveal
        end
      end
      resources :player_action_cards, only: [] do
        member do
          post :use
        end
      end
    end
  end
end
