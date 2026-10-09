#!/bin/bash
sed -i '' 's/static func launch(game: EpicGamesGame)/@MainActor static func launch(game: EpicGamesGame)/g' /Users/jackalope/Documents/WinGame/WinGame/Utilities/GameManager/EpicGamesGameManager.swift
sed -i '' 's/static func move(game: EpicGamesGame,/@MainActor static func move(game: EpicGamesGame,/g' /Users/jackalope/Documents/WinGame/WinGame/Utilities/GameManager/EpicGamesGameManager.swift
sed -i '' 's/static func uninstall(game: EpicGamesGame,/@MainActor static func uninstall(game: EpicGamesGame,/g' /Users/jackalope/Documents/WinGame/WinGame/Utilities/GameManager/EpicGamesGameManager.swift
