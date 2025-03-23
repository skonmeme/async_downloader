//
//  MLXView.swift
//  AsyncDownloader
//
//  Created by Sung Gon Yi on 3/24/25.
//

import Foundation
import SwiftUI

import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import MarkdownUI
import Metal
import Tokenizers

struct MLXView: View {
    
    @Environment(DeviceStat.self) var deviceStat

    @State private var llm = MLXLLMEvaluator()
    
    @State private var userPrompt: String = ""
    @State private var systemPrompt: String = ""
    @State var lmConfiguration: LMConfiguration
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Prompt with instruction")
                VStack {
                    HStack {
                        Text("System prompt")
                            .frame(width: 100)
                        TextEditor(text: $systemPrompt)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2...5)
                            .autocorrectionDisabled(true)
                            .disabled(llm.running)
                    }
                    HStack {
                        Text("User prompt")
                            .frame(width: 100)
                        TextEditor(text: $userPrompt)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2...10)
                            .autocorrectionDisabled(true)
                        //.onSubmit(generate)
                            .disabled(llm.running)
                        Button(action: {
                            generate()
                        }, label: {
                            Text("Generate")
                        })
                        .disabled(llm.running)
                    }
                }
            }
            .padding()
            ScrollView(.vertical) {
                ScrollViewReader { sp in
                    Group {
                        Markdown(llm.output)
                            .textSelection(.enabled)
                    }
                    .onChange(of: llm.output) { _, _ in
                        sp.scrollTo("bottom")
                    }
                }
            }
            .padding()
            HStack {
                Text(llm.modelInfo)
                    .textFieldStyle(.roundedBorder)
                Spacer()
                Text(llm.stat)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Label(
                    "Memory Usage: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))",
                    systemImage: "info.circle.fill"
                )
                .labelStyle(.titleAndIcon)
                .padding(.horizontal)
                .help(
                    Text(
                        """
                        Active Memory: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))/\(GPU.memoryLimit.formatted(.byteCount(style: .memory)))
                        Cache Memory: \(deviceStat.gpuUsage.cacheMemory.formatted(.byteCount(style: .memory)))/\(GPU.cacheLimit.formatted(.byteCount(style: .memory)))
                        Peak Memory: \(deviceStat.gpuUsage.peakMemory.formatted(.byteCount(style: .memory)))
                        """
                    )
                )
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        copyToClipboard(llm.output)
                    }
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc.fill")
                }
                .disabled(llm.output == "")
                .labelStyle(.titleAndIcon)
            }
            
        }
        .task {
            // pre-load the weights on launch to speed up the first generation
            _ = try? await llm.initialize(lmConfiguration)
        }
    }
    
    private func generate() {
        Task {
            await llm.generate(userPrompt: userPrompt, systemPrompt: systemPrompt, lmConfiguration: lmConfiguration)
        }
    }
    
    private func copyToClipboard(_ string: String) {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(string, forType: .string)
        #else
            UIPasteboard.general.string = string
        #endif
    }
    
}
