//
//  ContentView.swift
//  LockbusterPrototype
//
//  Created by Rohan MALIK on 2/12/21.
//

import SwiftUI


enum GameMode {
    case Speedrun
    case Countdown
    case ChessClock
}

struct ImageAnimated: UIViewRepresentable {
    let imageSize: CGSize
    let group: Int
    let lock: Int
    let duration: Double = 0.45

    func makeUIView(context: Self.Context) -> UIView {
        let imageNames = (1...13).map { "G\(group)L\(lock)F\($0)" }
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0
            , width: imageSize.width, height: imageSize.height))

        let animationImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        animationImageView.clipsToBounds = true
        animationImageView.layer.cornerRadius = 5
        animationImageView.autoresizesSubviews = true
        animationImageView.contentMode = UIView.ContentMode.scaleAspectFill

        var images = [UIImage]()
        imageNames.forEach { imageName in
            if let img = UIImage(named: imageName) {
                images.append(img)
            }
        }

        animationImageView.animationImages = images
        animationImageView.animationDuration = duration
        animationImageView.animationRepeatCount = 1
        animationImageView.startAnimating()

        containerView.addSubview(animationImageView)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<ImageAnimated>) {

    }
}


struct TimerView: View {
    @State var timeLeft = 60.00
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(format: "%.2f seconds remaining", timeLeft))
            .onReceive(timer, perform: { _ in
                if timeLeft > 0 { timeLeft -= 0.01 }
            }).padding(.top)
    }
}

// Backlog:
// 1) put a "back" button on the end screen that returns to mode select
// 2) try to refactor createLock() to be more concise and less repetitive while preserving functionality
// 3) add a timer to speedrun mode
// 4) add functionality where the player can select their target score or time for speedrun/countdown mode and create their own sub-modes
// 5) begin prototyping for "chess clock" mode

// --- game state variables ---
var gestureName = ""
var score = 0
var lockGroup = 1
var mode: GameMode = .Speedrun
var upgrades: [Int] = []
// --- speedrun mode ---
var finalTime = ""
var prevBestTime = 0.0
// --- countdown mode ---
var prevBestScore = 0
// --- both ---
var startTime: TimeInterval = 0.0

struct ContentView: View {
    @State var started: Bool = false
    @State var currentLock = 1
    @State var currentGestureDone = false
    @State var timeUp = false
    
    var body: some View {
        return VStack {
            if !started {  // "welcome screen"
                Text("Welcome to Lockbuster!").padding(.bottom).font(.system(size: 33))
                Button("Speedrun Mode", action: {
                    startTime = Date.timeIntervalSinceReferenceDate
                    print("starting game at time \(startTime)")
                    print("current PB is \(UserDefaults.standard.double(forKey: "hundredGesturesTime"))")
                    prevBestTime = UserDefaults.standard.double(forKey: "hundredGesturesTime")
                    upgrades = [20, 40, 60, 80]
                    self.started = true
                }).padding(.top).padding(.bottom).font(.system(size: 23))
                Button("Countdown Mode", action: {
                    startTime = Date.timeIntervalSinceReferenceDate
                    print("starting game at time \(startTime)")
                    print("current highscore is \(UserDefaults.standard.integer(forKey: "oneMinuteScore"))")
                    prevBestScore = UserDefaults.standard.integer(forKey: "oneMinuteScore")
                    mode = .Countdown
                    upgrades = [9, 18, 27, 36, 45]
                    _ = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false, block: {_ in
                        self.timeUp = true
                        if score > prevBestScore { UserDefaults.standard.set(score, forKey: "oneMinuteScore") }
                    })
                    self.started = true
                }).padding(.top).font(.system(size: 23))
            } else {
                if mode == .Speedrun {
                    if finalTime == "" {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)")
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75))
                        Text("Time: \(finalTime)s").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38))
                        let currentBest = Double(finalTime)!
                        if currentBest < prevBestTime {
                            Text("New best time!").padding(.top).font(.system(size: 26))
                            Text(String(format: "(Improved by %.3fs)", prevBestTime-currentBest)).padding(.top)
                        } else {
                            Text(String(format: "Best time: %.3fs", prevBestTime)).padding(.top)
                        }
                    }
                } else if mode == .Countdown {
                    if !timeUp {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)").padding(.bottom)
                        TimerView()
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75))
                        Text("Score: \(score)").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38))
                        if score > prevBestScore {
                            Text("New highscore!").padding(.top).font(.system(size: 26))
                            Text("Improved by \(score-prevBestScore)").padding(.top)
                        } else {
                            Text("Highscore: \(prevBestScore)").padding(.top)
                        }
                    }
                }
            }
        }
    }
    
    func animateLock() -> some View {
        return AnyView(
            VStack {
                Text("a").foregroundColor(.white).font(.system(size: 35))
                ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: (upgrades.contains(score) ? lockGroup-1 : lockGroup), lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        if mode == .Speedrun {
                            if score >= 5 {  // change for easier testing; revert to 100 for production
                                finalTime = String(format: "%.3f", Date.timeIntervalSinceReferenceDate-startTime)
                                if Double(finalTime)! < prevBestTime || prevBestTime == 0.0 {
                                    UserDefaults.standard.set(Double(finalTime)!, forKey: "hundredGesturesTime")
                                }
                            }
                        }
                        self.currentLock = Int.random(in: 1...5)
                        self.currentGestureDone = false
                    })
                })
            }
        )
    }
    
    func createLock() -> some View {
        let num = Int.random(in: 1...2) // change for simulator testing; revert to 23 for production
        if num == 1 {
            gestureName = "Double Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 2 {
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 3 {
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 4 {
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(MagnificationGesture().onEnded{_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 5 {
            gestureName = "Two Finger Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        TappableView(touches: 2, tappedCallback: {(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 6 {
            gestureName = "Three Finger Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        TappableView(touches: 3, tappedCallback: {(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 7 {
            gestureName = "Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .left, touches: 1, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 8 {
            gestureName = "Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .right, touches: 1, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 9 {
            gestureName = "Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .up, touches: 1, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 10 {
            gestureName = "Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .down, touches: 1, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 11 {
            gestureName = "Two Finger Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .left, touches: 2, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 12 {
            gestureName = "Two Finger Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .right, touches: 2, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 13 {
            gestureName = "Two Finger Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .up, touches: 2, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 14 {
            gestureName = "Two Finger Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .down, touches: 2, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 15 {
            gestureName = "Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .gesture(LongPressGesture(minimumDuration: 0.4).onEnded({_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true}))
                    }
                }
            )
        } else if num == 16 {
            gestureName = "Two Finger Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        LongPressableView(touches: 2, pressedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 17 {
            gestureName = "Three Finger Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        LongPressableView(touches: 3, pressedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 18 {
            gestureName = "Left Edge Pan"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        PannableView(edge: .left, pannedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 19 {
            gestureName = "Right Edge Pan"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        PannableView(edge: .right, pannedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 20 {
            gestureName = "Three Finger Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .left, touches: 3, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 21 {
            gestureName = "Three Finger Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .right, touches: 3, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 22 {
            gestureName = "Three Finger Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .up, touches: 3, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else {
            gestureName = "Three Finger Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G\(lockGroup)L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        DraggableView(direction: .down, touches: 3, draggedCallback:{(_, _) in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                            .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
