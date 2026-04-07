Rails.application.routes.draw do
  # Главная страница - создание новой игры
  root "games#new"

  resources :games, only: [ :new, :create, :show ] do
    # Добавим кнопку для ведущего "Вскрыть следующую категорию"
    member do
      post :reveal_next_round
      post :start_raid
      get :report
    end

    resources :players, only: [ :show ] do
      member do
        post :reveal_biology # Кнопка вскрытия биологии
        post :eliminate
      end
      resources :player_cards, only: [] do
        member do
          post :reveal       # Кнопка вскрытия любой карточки
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
