import SwiftUI

struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Whisper.cpp")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    Text("MIT License")
                        .padding(.horizontal)
                    Text("Copyright (c) 2022 Georgi Gerganov")
                        .padding(.horizontal)
                    Text("""
                    Permission is hereby granted, free of charge, to any person obtaining a copy \
                    of this software and associated documentation files (the "Software"), to deal \
                    in the Software without restriction, including without limitation the rights \
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
                    copies of the Software, and to permit persons to whom the Software is \
                    furnished to do so, subject to the following conditions:
                    """)
                    .padding(.horizontal)
                    Text("""
                    The above copyright notice and this permission notice shall be included in \
                    all copies or substantial portions of the Software.
                    """)
                    .padding(.horizontal)
                    Text("""
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
                    SOFTWARE.
                    """)
                    .padding(.horizontal)
                    Divider()
                }

                VStack(alignment: .leading) {
                    Text("SafariServicesUI")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    Text("MIT License")
                        .padding(.horizontal)
                    Text("Copyright (c) 2022 Hiroki Kato")
                        .padding(.horizontal)
                    Text("""
                    Permission is hereby granted, free of charge, to any person obtaining a copy \
                    of this software and associated documentation files (the "Software"), to deal \
                    in the Software without restriction, including without limitation the rights \
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
                    copies of the Software, and to permit persons to whom the Software is \
                    furnished to do so, subject to the following conditions:
                    """)
                    .padding(.horizontal)
                    Text("""
                    The above copyright notice and this permission notice shall be included in \
                    all copies or substantial portions of the Software.
                    """)
                    .padding(.horizontal)
                    Text("""
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
                    SOFTWARE.
                    """)
                    .padding(.horizontal)
                    Divider()
                }
                
                VStack(alignment: .leading) {
                    Text("PartialSheet")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    Text("MIT License")
                        .padding(.horizontal)
                    Text("Copyright (c) 2020 Andrea Miotto")
                        .padding(.horizontal)
                    Text("""
                    Permission is hereby granted, free of charge, to any person obtaining a copy \
                    of this software and associated documentation files (the "Software"), to deal \
                    in the Software without restriction, including without limitation the rights \
                    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
                    copies of the Software, and to permit persons to whom the Software is \
                    furnished to do so, subject to the following conditions:
                    """)
                    .padding(.horizontal)
                    Text("""
                    The above copyright notice and this permission notice shall be included in \
                    all copies or substantial portions of the Software.
                    """)
                    .padding(.horizontal)
                    Text("""
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
                    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
                    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
                    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
                    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
                    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
                    SOFTWARE.
                    """)
                    .padding(.horizontal)
                    Divider()
                }

                VStack(alignment: .leading) {
                    Text("Image: Freepik.com")
                        .font(.headline)
                        .padding(.top)
                        .padding(.horizontal)
                    Text("The frontpage image has been designed using assets from Freepik.com.")
                        .padding(.horizontal)
                }
            }
        }
    }
}
