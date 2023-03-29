import SwiftUI

public extension View {
  func showBottomView<Content>(
    isPresented: Binding<Bool>,
    min: CGFloat,
    max: CGFloat,
    @ViewBuilder contentBottomView: @escaping(() -> Content)
  ) -> some View where Content: View {
    modifier(
      BottomViewModifier(
        isPresented: isPresented,
        yMin: min,
        yMax: max,
        contentBottomView: contentBottomView()
      )
    )
  }
}

public struct BottomViewModifier<ContentBottomView>: ViewModifier where ContentBottomView: View {

  @Binding var isPresented: Bool
  var yMin: CGFloat
  var yMax: CGFloat
  let contentBottomView: ContentBottomView

  @State private var yOffset: CGFloat = 0
  @State private var yPosBeforeDrag: CGFloat = 0

  public init(isPresented: Binding<Bool>, yMin: CGFloat, yMax: CGFloat, contentBottomView: ContentBottomView) {
    self._isPresented = isPresented
    self.yMin = yMin
    self.yMax = yMax
    self.contentBottomView = contentBottomView
  }

  public func body(content: Content) -> some View {
    ZStack(alignment: .bottom) {
      content
      if $isPresented.animation(.spring()).wrappedValue {
        ZStack(alignment: .bottom) {
          Color.black.opacity(1/3)
            .onTapGesture {
              isPresented = false
            }
          VStack(spacing: 0) {
            TopBottomBarView(
              background: LinearGradient(
                colors: [.orange, .red].reversed(),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .gesture(DragGesture()
              .onChanged({ value in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.3, blendDuration: 0.1).speed(2/3).delay(1/3)) {
                  let change = value.translation.height
                  let newYOffset = yPosBeforeDrag - change
                  if newYOffset < yMax && newYOffset > yMin {
                    yOffset = newYOffset
                  }
                }
              })
                .onEnded { value in
                  withAnimation(.spring(response: 0.2, dampingFraction: 0.3, blendDuration: 0.1).speed(2/3).delay(1/3)) {
                    yPosBeforeDrag = yOffset
                  }
                }
            )
            contentBottomView
              .background(Color.white)
              .frame(maxWidth: .infinity, maxHeight: .infinity)

          }
          .frame(height: yOffset)
        }
        .onAppear {
          withAnimation() {
            yOffset = yMin
            yPosBeforeDrag = yMin
          }
        }
      }
    }
  }
}

public struct TopBottomBarView<Background>: View where Background: View {

  var background: Background

  public var body: some View {
    ZStack {
      ZStack {
        background
          .clipShape(TopBottomBarShape())
        TopBottomBarShape()
          .foregroundColor(Color.clear)
      }

      VStack(spacing: 0) {
        Spacer()
          .frame(height: 12)
        Capsule()
          .frame(width: 30, height: 7)
          .foregroundColor(Color.white)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 44)
  }
}

struct TopBottomBarShape: Shape {

  private var radius: CGFloat?

  init(radius: CGFloat? = nil) {
    self.radius = radius
  }

  func path(in rect: CGRect) -> Path {
    let radius = radius ?? rect.height/2
    var path = Path()
    path.move(to: CGPoint(x: 0, y: rect.height))
    path.addArc(center: CGPoint(x: radius, y: radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false)
    path.addLine(to: CGPoint(x: rect.width - rect.height, y: 0))
    path.addArc(center: CGPoint(x: rect.width - radius, y: radius),
                radius: radius,
                startAngle: .degrees(270),
                endAngle: .degrees(360),
                clockwise: false)
    path.addLine(to: CGPoint(x: rect.width, y: rect.height))
    path.addLine(to: CGPoint(x: 0, y: rect.height))
    return path
  }
}
