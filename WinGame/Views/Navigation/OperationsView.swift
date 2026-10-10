//
//  OperationsView.swift
//  WinGame
//
//  Created by vapidinfinity (esi) on 5/4/2024.
//

// Copyright © 2023-2026 vapidinfinity

import SwiftUI

struct OperationsView: View {
    @Bindable private var operationManager: GameOperationManager = .shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Downloads & Tasks")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Active game downloads, verification, and Wine engine background operations.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if operationManager.queue.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 76, height: 76)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                        }

                        VStack(spacing: 6) {
                            Text("All Operations Complete")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            Text("No pending game downloads or Wine configuration tasks in progress.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 320)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(operationManager.queue) { operation in
                            OperationCard(operation: .constant(operation))
                        }
                    }
                }

                Spacer()
            }
            .padding(32)
        }
    }
}

#Preview {
    OperationsView()
}
